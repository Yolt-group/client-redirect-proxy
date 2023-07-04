
all: test

# Create certificates that are valid until perpetuity (for all practical purposes)
pki:
	rm -rf pki
	mkdir -p pki
	step certificate create "Yolt Fake CA" \
		pki/issuing_ca pki/root.key \
		--not-after=2500-01-01T00:00:00Z \
		--profile root-ca \
		--force --no-password --insecure
	step certificate create client-redirect-proxy \
		pki/cert pki/private_key \
		--not-after=2500-01-01T00:00:00Z \
		--ca pki/issuing_ca --ca-key pki/root.key \
		--profile leaf \
		--force --no-password --insecure
	step certificate create site-management \
		pki/site-management.crt pki/site-management.key \
		--not-after=2500-01-01T00:00:00Z \
		--ca pki/issuing_ca --ca-key pki/root.key \
		--profile leaf \
		--force --no-password --insecure
	step certificate create pis \
		pki/pis.crt pki/pis.key \
		--not-after=2500-01-01T00:00:00Z \
		--ca pki/issuing_ca --ca-key pki/root.key \
		--profile leaf  \
		--force --no-password --insecure

build: pki
	docker-compose build

test: build
	docker-compose up -d client-redirect-proxy
	docker-compose up tests
	docker-compose down

.PHONY: all pki build test
