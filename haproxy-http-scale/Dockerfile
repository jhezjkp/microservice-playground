FROM python:2.7
RUN mkdir /app
WORKDIR /app
ADD requirements.txt /app
ADD app.py /app
RUN pip install -r requirements.txt
CMD python app.py

