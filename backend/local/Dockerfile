FROM python:3.12-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY local/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY local/ /app/
COPY GestionProyectos/ /app/GestionProyectos/

EXPOSE 8000
CMD ["python", "entrypoint.py"]
