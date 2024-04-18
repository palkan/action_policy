default: test

nextify:
	bundle exec rake nextify

test: nextify
	bundle exec rake
	CI=true bundle exec rake

lint:
	bundle exec rubocop

release: test lint
	git status
	RELEASING_GEM=true gem release -t
	git push
	git push --tags

ci-release: test lint
	RELEASING_GEM=true gem release
