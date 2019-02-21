# Self-contained Dockerfile for Meteor app deployment

This production-ready Dockerfile will build and prepare your Meteor app server for deployment. It is a [multistage Dockerfile](https://docs.docker.com/develop/develop-images/multistage-build/), meaning that the final Docker image is based on a small, simple Alpine Linux image that does not have Meteor or build dependencies installed.

I put together this Dockerfile because I didn't want my Docker deployment to depend on other Meteor Docker images that may or may not be maintained in the future -- it only uses official NodeJS Docker images as base images. And I wanted everything to be in one self-contained file, so that I could understand what was happening more clearly.

This Dockerfile is based *heavily* on the work of
Geoffrey Booth ([geoffreybooth/meteor-base](https://github.com/disney/meteor-base)) and
Pascal Kaufmann ([pozylon/meteor-docker-auto](https://github.com/pozylon/meteor-docker-auto)). I mostly just pieced things together based on their work. Many thanks to them!

## How to use

1. Copy the Dockerfile into your Meteor app root.

2. Edit the `ENV METEOR_VERSION` line to match your Meteor version (as shown in your app's `.meteor/release`).

3. Edit the two `FROM node:8.11.4...` lines to match the version of Node used by your version of Meteor (check the [Meteor changelog](https://docs.meteor.com/changelog.html) to see what Node version is being used).

If you'd like to put your Dockerfile in a directory other than your Meteor app root, be sure to change `APP_SRC_FOLDER=.` to be equal to your app root directory (relative to the Dockerfile).

### Example `docker-compose.yml` for testing

The easiest way to try this out after you've set up your Dockerfile is to copy the example `docker-compose.yml` file into the same directory as your Dockerfile and run `docker-compose up`.

## Notes

This is a generic Meteor deployment Dockerfile, with no app-specific code.

During the "Building Meteor bundle" step, you'll see a warning about the `--allow-superuser` flag. This warning is irrelevant in this case and can be safely ignored.

If the process is killed while building the bundle, it is probably because it ran out of memory. Make sure you have enough RAM available in the Docker VM if applicable. (I need 2+ GB to build my app successfully.)

Needless to say, don't forget to update this Dockerfile when you update your Meteor deployment! (Perhaps this step could be automated, but I prefer to simply add it to my manual process during Meteor release upgrades.)
