srun\
    --time=24:00:00\
    -p gpu-a40\
    -A escience\
    --cpus-per-task=4\
    --gpus=2\
    --mem=32G\
    make yellowearth
