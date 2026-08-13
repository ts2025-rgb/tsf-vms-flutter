export async function onRequest(context) {
  const { request, params } = context;
  const path = Array.isArray(params.path) ? params.path.join('/') : params.path || '';
  const backendBase = 'https://tsf-backend-production.up.railway.app';

  const url = new URL(request.url);
  url.protocol = 'https:';
  url.hostname = new URL(backendBase).hostname;
  url.port = '';
  url.pathname = `/api/${path}`;

  const headers = new Headers(request.headers);
  headers.delete('host');

  const response = await fetch(url.toString() + url.search, {
    method: request.method,
    headers,
    body: request.body,
    redirect: 'manual',
  });

  return response;
}
