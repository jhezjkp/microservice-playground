#a load balance demo app

FROM python:2.7-alpine
RUN mkdir /app
WORKDIR /app
ADD requirements.txt /app
ADD app.py /app
EXPOSE 5000
RUN pip install -r requirements.txt
CMD python app.py

