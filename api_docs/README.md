## API docs

To generate new docs:

```
$ cd api_docs
$ docker build -t dociql .
$ docker run -v $PWD/public:/src/public --net=host -it --rm dociql npx dociql config.yml
```
