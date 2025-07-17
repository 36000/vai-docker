.PHONY: help

HOSTNAME := $(shell hostname)
UID := $(shell id -u)
GID := $(shell id -g)
IMAGE := topaz-vai

# Change these two if you want to build a different version
VAI_VERSION := 5.0.3.1.b
VAI_SHA2 := 258627001c685aa9feed34a013b48003456f5fc5239151d6a5d5440b51fc795e

TAG := $(shell echo ${VAI_VERSION} | sed 's/\.//g')

help:
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[1;32m%-10s\033[0m %s\n", $$1, $$2}'

build:    ## Build image capable of using fp16/32 models
	apptainer build --nv --force ${IMAGE}.sif topaz.def

login:    ## Refresh the auth.tpz license file
	APPTAINERENV_HOSTNAME=$(HOSTNAME) \
	apptainer run --nv --net --fakeroot --network=host \
		--bind $(PWD)/auth:/auth \
		--writable-tmpfs \
		${IMAGE}.sif login

yellowearth:
	apptainer run --nv --cleanenv --containall --writable-tmpfs \
		--bind "$(PWD)/models:/models,$(PWD)/movies:/movies,$(PWD)/auth/auth.tpz:/opt/TopazVideoAIBETA/models/auth.tpz,$(PWD):/workspace" \
		${IMAGE}.sif \
		ffmpeg -hide_banner -i /movies/yellowearth.mp4 \
		-sws_flags spline+accurate_rnd+full_chroma_int \
		-filter_complex "bwdif=mode=0:parity=-1:deint=0,tvai_up=model=iris-3:scale=1:preblur=0:noise=0:details=0:halo=0:blur=0:compression=0:estimate=8:device=0:vram=1:instances=1,tvai_up=model=thd-3:scale=0:w=640:h=480:noise=0:blur=1:compression=0:prenoise=0.02:device=0:vram=1:instances=1,tvai_up=model=hyp-1:scale=1:w=640:h=480:parameters='sdr_ip=0.7\:hdr_ip_adjust=1\:saturate=0.3':device=0:vram=1:instances=1,setparams=range=pc:color_primaries=bt2020:color_trc=smpte2084:colorspace=bt2020nc,scale=w=640:h=480:flags=lanczos:threads=0:force_original_aspect_ratio=decrease,pad=640:480:-1:-1:color=black" \
		-c:v h264_videotoolbox \
		-profile:v high \
		-pix_fmt yuv420p \
		-g 30 \
		-b:v 0 \
		-q:v 82 \
		-map 0:a? \
		-map_metadata:s:a:0 0:s:a:0 \
		-map_metadata:s:a:1 0:s:a:1 \
		-c:a copy \
		-bsf:a:0 aac_adtstoasc \
		-map_metadata 0 \
		-map_metadata:s:v 0:s:v \
		-fps_mode:v passthrough \
		-movflags frag_keyframe+empty_moov+delay_moov+use_metadata_tags+write_colr \
		-bf 0 \
		-metadata "videoai=Deinterlaced and enhanced using iris-3; mode: auto; revert compression at 0; recover details at 0; sharpen at 0; reduce noise at 0; dehalo at 0; anti-alias/deblur at 0; and focus fix Off. Enhanced using thd-3; revert compression at 0; sharpen at 100; reduce noise at 0; focus fix Off; and add noise at 2. HDR Enhanced using hyp-1; exposure at 1; saturation at 0.3; and highlight threshold at 0.7. Changed resolution to 640x480" \
		/movies/yellowearth_corrected.mp4

# test:     ## Run a smoke test doing a 2x upscale with Protheus
# 	docker run --rm -ti --gpus all --user $(UID):$(GID) --name vai-test --hostname $(HOSTNAME) \
# 		-v $(PWD)/models:/models \
# 		-v $(PWD)/auth/auth.tpz:/opt/TopazVideoAIBETA/models/auth.tpz \
# 		-v $(PWD):/workspace \
# 		$(IMAGE) \
# 		ffmpeg -v verbose -y -f lavfi -i testsrc=duration=12:size=320x180:rate=15 -pix_fmt yuv420p \
# 		-flush_packets 1 -sws_flags spline+accurate_rnd+full_chroma_int \
# 		-color_trc 2 -colorspace 2 -color_primaries 2 \
# 		-filter_complex "tvai_up=model=prob-3:scale=2:preblur=-0.6:noise=0:details=1:halo=0.03:blur=1:compression=0:estimate=20:blend=0.8:device=0:vram=1:instances=1" \
# 		-c:v h264_nvenc -profile:v high -preset medium -b:v 0 \
# 		sample_prob3_2x_upscaled.mp4

# benchmark: ## Run a prob3 2x upscale benchmark
# 	docker run --rm -ti --gpus all --user $(UID):$(GID) --name vai-bench --hostname $(HOSTNAME) -v $(PWD)/models:/models $(IMAGE) \
# 		ffmpeg -v verbose -f lavfi -i testsrc=duration=60:size=640x480:rate=30 -pix_fmt yuv420p \
# 		-filter_complex "tvai_up=model=prob-3:scale=2:preblur=-0.6:noise=0:details=1:halo=0.03:blur=1:compression=0:blend=0.8:device=0:vram=1:instances=1" \
# 		-f null -
