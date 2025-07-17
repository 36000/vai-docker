srun\
    --time=4:00:00\
    -p gpu-a40\
    -A escience\
    --export=NONE\
    --cpus-per-task=16\
    --gpus=2 \
    --mem=128G\
    make yellowearth
