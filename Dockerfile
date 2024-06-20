FROM debian:bullseye

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libatlas-base-dev \
        libblas-dev \
        libbz2-dev \
        libffi-dev \
        libgdbm-dev \
        libjpeg-dev \
        liblcms2-dev \
        libldap2-dev \
        libncurses5-dev \
        libnss3-dev \
        libpq-dev \
        libreadline-dev \
        libsasl2-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        node-less \
        npm \
        wget \
        xz-utils \
        zlib1g-dev \
        lsb-release \
        libffi-dev \
        uuid-dev \
        libgdbm-dev \
        tk-dev \
        libdb-dev

# Install Python 3.10
RUN curl -O https://www.python.org/ftp/python/3.10.12/Python-3.10.12.tgz && \
    tar -xzf Python-3.10.12.tgz && \
    cd Python-3.10.12 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    cd .. && \
    rm -rf Python-3.10.12 Python-3.10.12.tgz

# Remove existing python3 link if it exists and set Python 3.10 as the default python3
RUN rm -f /usr/bin/python3 && ln -s /usr/local/bin/python3.10 /usr/bin/python3

# Install pip
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Retrieve the target architecture to install the correct wkhtmltopdf package
RUN if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    WKHTMLTOPDF_ARCH=${TARGETARCH} && \
    case ${TARGETARCH} in \
    "amd64") WKHTMLTOPDF_ARCH=amd64 && WKHTMLTOPDF_SHA=9df8dd7b1e99782f1cfa19aca665969bbd9cc159  ;; \
    "arm64")  WKHTMLTOPDF_SHA=58c84db46b11ba0e14abb77a32324b1c257f1f22  ;; \
    "ppc64le" | "ppc64el") WKHTMLTOPDF_ARCH=ppc64el && WKHTMLTOPDF_SHA=7ed8f6dcedf5345a3dd4eeb58dc89704d862f9cd  ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bullseye_${WKHTMLTOPDF_ARCH}.deb \
    && echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install node packages
RUN npm install -g rtlcss less less-plugin-clean-css

# Create and activate a virtual environment
RUN python3.10 -m venv /opt/odoo-venv
ENV PATH="/opt/odoo-venv/bin:$PATH"

# Install Odoo requirements and additional packages within the virtual environment
RUN pip install wheel debugpy py3dns validate_email regex jingtrang unidecode fastapi python-multipart ujson a2wsgi parse-accept-language pyjwt
RUN pip install -r https://raw.githubusercontent.com/odoo/odoo/16.0/requirements.txt

# Install Odoo
ENV ODOO_VERSION 16.0
ARG ODOO_RELEASE=latest
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb && \
    apt-get update && \
    apt-get -y install --no-install-recommends ./odoo.deb && \
    rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for user addons
RUN mkdir -p /mnt/extra-addons && \
    chown odoo:odoo /etc/odoo/odoo.conf && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chown -R odoo:odoo /var/lib/odoo/

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Implement remote-attach hook for debugging
RUN set -x; \
    echo "import debugpy" >> /usr/lib/python3/dist-packages/odoo/__init__.py && \
    echo "debugpy.listen(('0.0.0.0', 3000))" >> /usr/lib/python3/dist-packages/odoo/__init__.py && \
    echo "debugpy.wait_for_client()" >> /usr/lib/python3/dist-packages/odoo/__init__.py && \
    echo "debugpy.breakpoint()" >> /usr/lib/python3/dist-packages/odoo/__init__.py

# Expose Odoo services
EXPOSE 80 8080 8069 8071 8072 25 53/udp 53/tcp 443

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set default user when running the container
RUN usermod -u 1000 odoo && \
    groupmod -g 1000 odoo && \
    chown odoo:odoo /etc/odoo/odoo.conf && \
    chown -R odoo:odoo /mnt/extra-addons && \
    chown -R odoo:odoo /var/lib/odoo/

# Add the virtual environment to the PYTHONPATH
ENV PYTHONPATH="/opt/odoo-venv/lib/python3.10/site-packages:/usr/lib/python3/dist-packages"

USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
