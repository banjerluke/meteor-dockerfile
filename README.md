# Self-contained Dockerfile for Meteor app deployment

This production-ready Dockerfile will build and prepare your Meteor app server for deployment. It is a [multistage Dockerfile](https://docs.docker.com/develop/develop-images/multistage-build/), meaning that the final Docker image is based on a small, simple Alpine Linux image that does not have Meteor or build dependencies installed.

I put together this Dockerfile because I didn't want my Docker deployment to depend on other Meteor Docker images that may or may not be maintained in the future -- it only uses official NodeJS Docker images as base images. And I wanted everything to be in one self-contained file, so that I could understand what was happening more clearly.

This Dockerfile is based *heavily* on the work of
Geoffrey Booth ([geoffreybooth/meteor-base](https://github.com/disney/meteor-base)) and
Pascal Kaufmann ([pozylon/meteor-docker-auto](https://github.com/pozylon/meteor-docker-auto)). I mostly just pieced things together based on their work. Many thanks to them!

## How to use

1. Copy the Dockerfile into your Meteor app root.

2. Edit the `ENV METEOR_VERSION` line to match your Meteor version (as shown in your app's `.meteor/release`).

3. Edit the two `FROM node:8.15.1...` lines to match the version of Node used by your version of Meteor (check the [Meteor changelog](https://docs.meteor.com/changelog.html) to see what Node version is being used).

If you'd like to put your Dockerfile in a directory other than your Meteor app root, be sure to change `APP_SRC_FOLDER=.` to be equal to your app root directory (relative to the Dockerfile).

### Example `docker-compose.yml` for testing

The easiest way to try this out after you've set up your Dockerfile is to copy `example/docker-compose.yml` into the same directory as your Dockerfile and run `docker-compose up`.

### `cloudbuild.yaml` for Google Cloud Build

If you'd like to use Google Cloud Build to build your Meteor app, take a look at `example/cloudbuild.yaml`. Using this build config (by putting the file in the root directory of your git repo) will properly cache the first builder stage for later rebuilds. In practice, there's not a whole lot of benefit to this -- yes, it keeps Meteor from being downloaded and installed every time, and it caches app NPM dependencies too, but the bulk of the build time will be taken up by the Meteor server build step, which needs to be re-run every time your code changes anyway.

The `cloudbuild.yaml` file also increases the build timeout to 20 minutes (`timeout: 1200s`) because I kept bumping up against the default 10 minute build timeout in Google Cloud Build.

## Notes

This is a generic Meteor deployment Dockerfile, with no app-specific code.

During the "Building Meteor bundle" step, you'll see a warning about the `--allow-superuser` flag. This warning is irrelevant in this case and can be safely ignored.

If the process is killed while building the bundle, it is probably because it ran out of memory. Make sure you have enough RAM available in the Docker VM if applicable. (I need 2+ GB to build my app successfully. Ended up moving the building to Google Cloud Build which offers 120 free build minutes a day and no memory issues so far.)

Needless to say, don't forget to update this Dockerfile when you update your Meteor deployment! (Perhaps this step could be automated, but I prefer to simply add it to my manual process during Meteor release upgrades.)

A previous version of this Dockerfile modified the built Node server to inject an environment variable with the git commit hash, but since Meteor 1.8.1 that is no longer necessary since you can use [Meteor.gitCommitHash](https://github.com/meteor/meteor/pull/10442).
