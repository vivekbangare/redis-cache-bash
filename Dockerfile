FROM redis:latest
LABEL maintainer="vivek bangare <vivek.bangare@gmail.com>"
# Copy the redis.conf file into the container
COPY redis.conf /usr/local/etc/redis/redis.conf
# Override the default command to use the custom configuration file
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]