FROM public.ecr.aws/amazonlinux/amazonlinux:latest as build_kinesis
RUN curl -sL -o /bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
RUN chmod +x /bin/gimme
RUN yum upgrade -y && yum install -y tar gzip git make gcc
ENV HOME /home
RUN /bin/gimme 1.17
ENV PATH ${PATH}:/home/.gimme/versions/go1.17.linux.arm64/bin:/home/.gimme/versions/go1.17.linux.amd64/bin
RUN go version
ENV GO111MODULE on
RUN go env -w GOPROXY=direct

ARG KINESIS_PLUGIN_CLONE_URL=https://github.com/Adaptavist/amazon-kinesis-streams-for-fluent-bit.git
ARG KINESIS_PLUGIN_TAG=""
ARG KINESIS_PLUGIN_BRANCH="mainline"

# Kinesis Streams

RUN git clone $KINESIS_PLUGIN_CLONE_URL /kinesis-streams
WORKDIR /kinesis-streams
RUN if [ -n "$KINESIS_PLUGIN_BRANCH" ];then git fetch --all && git checkout $KINESIS_PLUGIN_BRANCH && git remote -v;fi
RUN if [ -z "$KINESIS_PLUGIN_BRANCH" ];then git fetch --all --tags && git checkout tags/$KINESIS_PLUGIN_TAG -b $KINESIS_PLUGIN_TAG && git describe --tags;fi
RUN go mod download
RUN make release


FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:latest
ADD conf /
COPY --from=build_kinesis /kinesis-streams/bin/kinesis.so /fluent-bit/kinesis.so
