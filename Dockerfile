# --- Stage 1: build Meteor app and install its NPM dependencies ---

# Make sure both this and the FROM line further down match the
# version of Node expected by your version of Meteor -- see https://docs.meteor.com/changelog.html
FROM node:8.11.4 as builder

# METEOR_VERSION should match the version in your .meteor/release
# APP_SRC_FOLDER is path the your app code relative to this Dockerfile
# BUILD_SRC_FOLDER is where app code is copied into the container
# BUILD_OUTPUT_FOLDER is where app code is built within the container (there's a matching ENV line in the second stage)
ENV METEOR_VERSION=1.8.0.2 \
    APP_SRC_FOLDER=. \
    BUILD_SRC_FOLDER=/opt/src \
    BUILD_OUTPUT_FOLDER=/opt/app

RUN mkdir -p $BUILD_OUTPUT_FOLDER $BUILD_SRC_FOLDER

RUN echo "\n[*] Installing Meteor ${METEOR_VERSION} to ${HOME}"\
&& curl -s https://install.meteor.com/?release=${METEOR_VERSION} | sed s/--progress-bar/-sL/g | sh

WORKDIR $BUILD_SRC_FOLDER

# Copy in NPM dependencies and install them
COPY $APP_SRC_FOLDER/package*.json $BUILD_SRC_FOLDER/
RUN echo '\n[*] Installing app NPM dependencies' \
&& meteor npm install --only=production

# Copy app source into container and build
COPY $APP_SRC_FOLDER $BUILD_SRC_FOLDER/
RUN echo '\n[*] Building Meteor bundle' \
&& meteor build --server-only --allow-superuser --directory $BUILD_OUTPUT_FOLDER

# Note: the line above will show a warning about the --allow-superuser flag.
# You can safely ignore it, as it doesn't apply here. The server *is* being built, silently.
# If the process gets killed after awhile, it's probably because the Docker VM ran out of memory.

# Inject git commit into server boot; only necessary if you want the git commit hash to be 
# accessible as an environment variable in your Meteor app
RUN (echo "process.env.COMMIT_ID = '$(git rev-parse HEAD)';"; cat $BUILD_OUTPUT_FOLDER/bundle/main.js) > new-main.js && mv new-main.js $BUILD_OUTPUT_FOLDER/bundle/main.js


# --- Stage 2: install server dependencies and run Node server ---

FROM node:8.11.4-alpine as runner

ENV BUILD_OUTPUT_FOLDER /opt/app

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
COPY --from=builder $BUILD_OUTPUT_FOLDER $BUILD_OUTPUT_FOLDER/

# Install NPM dependencies for the Meteor server, then remove OS build dependencies
RUN echo '\n[*] Installing Meteor server NPM dependencies' \
&& cd $BUILD_OUTPUT_FOLDER/bundle/programs/server/ \
&& npm install && npm run install --production \
&& apk del .node-gyp-compilation-dependencies

# Move into bundle folder
WORKDIR $BUILD_OUTPUT_FOLDER/bundle/

CMD ["node", "main.js"]
