srun\
    --time=4:00:00\
    -p gpu-rtx6k\
    -A escience\
    --cpus-per-task=4\
    --gpus=1\
    --mem=32G\
    make yellowearth
