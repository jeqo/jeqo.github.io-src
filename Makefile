.PHONY: all
all:

msg := "rebuilding site"

.PHONY: deploy
deploy:
	hugo
	cd public/; git checkout main;
	cd public/; git add -A
	cd public/; git commit -m ${msg}
	cd public/; git push origin main

test:
	hugo serve -D