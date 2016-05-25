FROM python:2.7-alpine
MAINTAINER jhezjkp
LABEL service.name=demo
LABEL service.version="1.0"
LABEL service.description="this is a micro service demo"
LABEL environment=product
WORKDIR /app
COPY app.py requirements.txt ./
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python app.py

