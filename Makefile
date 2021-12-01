.PHONY: all
all:

msg := "rebuilding site"

.PHONY: deploy
deploy:
	hugo
	cd public/; \
		git checkout main && \
		git add -A && \
		git commit -m ${msg} && \
		git push origin main

test:
	hugo serve -D