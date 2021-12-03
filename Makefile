.PHONY: osra-image
osra-image:
	docker build . -t ghcr.io/strrl/osra:latest
