DOCKER_NOOP_VOLUME="beyondfa_baseline-volume"
input_dir="$PWD/data/dummy_challenge_input"
output_dir="$PWD/results"

mkdir -p "$output_dir"

docker build . -t beyond_fa_scil_team
docker volume create "$DOCKER_NOOP_VOLUME" > /dev/null
docker run \
    -it \
    --platform linux/amd64 \
    --network none \
    --rm \
    --volume $input_dir:/input:ro \
    --volume $output_dir:/output \
    --volume "$DOCKER_NOOP_VOLUME":/tmp \
    --mount type=bind,source=$PWD/work,target=/nextflow/work \
    beyond_fa_scil_team
docker volume rm "$DOCKER_NOOP_VOLUME" > /dev/null
