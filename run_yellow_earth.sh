rm movies/yellowearth_corrected.mp4

srun\
    --time=48:00:00\
    -p gpu-a40\
    -A escience\
    --cpus-per-task=1\
    --gpus=2\
    --mem=32G\
    make yellowearth
