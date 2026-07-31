# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec files first to leverage Docker cache
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Build the web app with environment variables passed as dart-defines
# These should be provided during build time or set as build-args
ARG SCA_API_URL
ARG SCA_COMMUNITY_SLUG
ARG SUPABASE_URL
ARG SUPABASE_PUBLISHABLE_KEY

RUN flutter build web \
    --dart-define=SCA_API_URL=$SCA_API_URL \
    --dart-define=SCA_COMMUNITY_SLUG=$SCA_COMMUNITY_SLUG \
    --dart-define=SUPABASE_URL=$SUPABASE_URL \
    --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY \
    --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the build output to Nginx's html directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
