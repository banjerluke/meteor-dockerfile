# --- Stage 1: build Meteor app and install its NPM dependencies ---

# Make sure both this and the FROM line further down match the
# version of Node expected by your version of Meteor -- see https://docs.meteor.com/changelog.html
FROM node:8.15.1 as builder

# METEOR_VERSION should match the version in your .meteor/release
# APP_SRC_FOLDER is path the your app code relative to this Dockerfile
# /opt/src is where app code is copied into the container
# /opt/app is where app code is built within the container
ENV METEOR_VERSION=1.8.1 \
    APP_SRC_FOLDER=.

RUN mkdir -p /opt/app /opt/src

RUN echo "\n[*] Installing Meteor ${METEOR_VERSION} to ${HOME}"\
&& curl -s https://install.meteor.com/?release=${METEOR_VERSION} | sed s/--progress-bar/-sL/g | sh

WORKDIR /opt/src

# Copy in NPM dependencies and install them
COPY $APP_SRC_FOLDER/package*.json /opt/src/
RUN echo '\n[*] Installing app NPM dependencies' \
&& meteor npm install --only=production

# Copy app source into container and build
COPY $APP_SRC_FOLDER /opt/src/
RUN echo '\n[*] Building Meteor bundle' \
&& meteor build --server-only --allow-superuser --directory /opt/app

# Note: the line above will show a warning about the --allow-superuser flag.
# You can safely ignore it, as it doesn't apply here. The server *is* being built, silently.
# If the process gets killed after awhile, it's probably because the Docker VM ran out of memory.


# --- Stage 2: install server dependencies and run Node server ---

FROM node:8.15.1-alpine as runner

ENV NODE_ENV=production

# Install OS build dependencies, which we remove later after we’ve compiled native Node extensions
RUN apk --no-cache --virtual .node-gyp-compilation-dependencies add \
		g++ \
		make \
		python \
	# And runtime dependencies, which we keep
	&& apk --no-cache add \
		bash \
		ca-certificates

# Copy in app bundle built in the first stage
COPY --from=builder /opt/app/bundle /opt/app/

# Install NPM dependencies for the Meteor server, then remove OS build dependencies
RUN echo '\n[*] Installing Meteor server NPM dependencies' \
&& cd /opt/app/programs/server/ \
&& npm install --production && npm run install --production \
&& apk del .node-gyp-compilation-dependencies

# Move into bundle folder
WORKDIR /opt/app/

CMD ["node", "main.js"]
