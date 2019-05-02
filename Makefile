copy-styles:
	cp -r ../odca-jekyll/_sass/ app/assets/stylesheets/_sass
	mv app/assets/stylesheets/_sass app/assets/stylesheets/odca-jekyll
	cp ../odca-jekyll/assets/images/open-disclosure-favicon.ico app/assets/images
	cp ../odca-jekyll/assets/images/open-disclosure-splash.png app/assets/images
