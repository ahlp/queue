FROM google/dart:latest

COPY ./ ./
RUN pub get

EXPOSE 3000
CMD dart src/main.dart
