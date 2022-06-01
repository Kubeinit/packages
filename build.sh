#!/bin/bash
set -eo pipefail

# Merge all Dockerfile.xx to an all-in-one file
ls Dockerfile.* | xargs -L1 grep -Ev 'FROM scratch|COPY --from=' > Dockerfile
echo "FROM scratch" >> Dockerfile
ls Dockerfile.* | xargs -L1 grep 'COPY --from=' >> Dockerfile

# Export build artifact to local path
DOCKER_BUILDKIT=1 docker build -o type=local,dest=$PWD -f Dockerfile .

docker image list

# id=$(docker create image-name)
# docker cp $id:path - > local-tar-file
# docker rm -v $id
# docker create --name suspect-container suspect-image:latest
# docker export suspect-container > suspect-container.tar
