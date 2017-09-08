FROM ubuntu

RUN apt-get update
RUN apt-get install -y ruby
RUN apt-get install -y python
RUN apt-get install -y clang
RUN apt-get install -y time
RUN apt-get install -y binutils

RUN apt-get install -y language-pack-ja-base language-pack-ja

ENV LANG ja_US.UTF-8
ENV LC_ALL ja_JP.UTF-8
ENV LC_CTYPE ja_JP.UTF-8