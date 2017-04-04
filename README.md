# In Touch
Reader Relationship Management for journalists

## Getting started

### Prerequisites

* Perl 5.10+
* Python 2.7+
* MongoDB 2+
* Google Cloud API [service key](https://cloud.google.com/natural-language/docs/common/auth)

Should run fine on system Perl/Python, but recommend using [perlbrew](https://perlbrew.pl/) and Python equivalent.

### Installing

Make a copy of in_touch.conf.sample to in_touch.conf:

```
cp in_touch.conf.sample in_touch.conf
```

Customise the config file as appropriate.

Find the following file:

```
public/form-builder/assets/js/templates/app/renderformIframe.html
```

And update the `&lt;form action=` attribute to point to your server.

Next find the file:

```
public/form-builder/assets/js/views/my-form.js
```

And change line 51 to point to your server.

Install the necessary Perl modules using [cpanm](https://metacpan.org/pod/App::cpanminus):

```
cpanm Mojolicious Try::Tiny MongoDB Data::Random
```

Install the necessary Python modules using [pip](https://pypi.python.org/pypi/pip):

```
pip install google-cloud argparse json
```

Run the development server using:

```
morbo script/in_touch
```

Run the Facebook script using:

```
perl bin/fetch-facebook-messages.pl
```

**Note:** If you want the form submission text to come through to the dashboard, you must change one of the form field IDs to **__msg__** - ideally a text or textarea field

## Built With

* [Mojolicious](http://mojolicious.org/) - Next generation web framework for Perl
* [Bootstrap Form Builder](https://github.com/minikomi/Bootstrap-Form-Builder/) - Javascript Bootstrap form generator
* [Google Cloud Python](https://googlecloudplatform.github.io/google-cloud-python/) - Python interface to Google Cloud APIs

## Authors

* **[Rob Hammond](https://github.com/robhammond)**
* **[Miguel Isidoro](https://github.com/misidoro)**
* **Mark Geary**

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details