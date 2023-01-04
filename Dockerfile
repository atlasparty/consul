FROM ruby:2.7.6-buster

ENV DEBIAN_FRONTEND noninteractive

# Set docker args
ARG RAILS_ENV
ARG RAILS_LOG_TO_STDOUT
ARG RAILS_SERVE_STATIC_FILES
ARG SECRET_KEY_BASE
ARG SERVER_NAME
ARG DATABASE_HOST
ARG DATABASE_PORT
ARG DATABASE_NAME
ARG DATABASE_USERNAME
ARG DATABASE_PASSWORD
ARG FORCE_SSL

ARG SMTP_HOST
ARG SMTP_PORT
ARG SMTP_EMAIL_DOMAIN
ARG SMTP_EMAIL_USERNAME
ARG SMTP_EMAIL_PASSWORD
ARG SMTP_AUTHENTICATION

# Install essential Linux packages
RUN apt-get update -qq \
 && apt-get install -y \
    build-essential \
    cmake \
    imagemagick \
    libappindicator1 \
    libindicator7 \
    libpq-dev \
    libxss1 \
    memcached \
    nodejs \
    pkg-config \
    postgresql-client \
    shared-mime-info \
    sudo \
    unzip

# Install Chromium for E2E integration tests
# RUN apt-get update -qq && apt-get install -y chromium

# Files created inside the container repect the ownership
RUN adduser --shell /bin/bash --disabled-password --gecos "" consul \
 && adduser consul sudo \
 && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bundle/bin"' > /etc/sudoers.d/secure_path
RUN chmod 0440 /etc/sudoers.d/secure_path

# Define where our application will live inside the image
ENV RAILS_ROOT /var/www/consul

# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir -p $RAILS_ROOT/tmp/pids

# Set our working directory inside the image
WORKDIR $RAILS_ROOT

# Use the Gemfiles as Docker cache markers. Always bundle before copying app src.
# (the src likely changed and we don't want to invalidate Docker's cache too early)
COPY Gemfile* ./
RUN bundle install

# Copy the Rails application into place
COPY . .

# precompile assets
RUN rake assets:precompile

# Set consul user as dir owner
RUN chown -R consul:consul $RAILS_ROOT

# Expose the port rails runs on
EXPOSE 8080

ENTRYPOINT ["./docker-entrypoint.sh"]
# Define the script we want run once the container boots
# Use the "exec" form of CMD so our script shuts down gracefully on SIGTERM (i.e. `docker stop`)
# CMD [ "config/containers/app_cmd.sh" ]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
