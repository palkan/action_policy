import express from 'express';
import setCookieParser from 'set-cookie-parser';
import multer from 'multer';
import createFrameLocationTrackingMiddleware from './server/frame_location_middleware.js';

class IncomingRequest {
  // We prepare input outside to avoid async Ruby execution for now
  constructor(request, input = nil) {
    this.request = request;
    this.input = input;
    this._preparedHeaders = undefined;
  }

  method() {
    return this.request.method;
  }

  pathWithQuery() {
    const url = this.request.url;
    return url ? url : null;
  }

  scheme() {
    return this.request.protocol;
  }

  authority() {
    const host = this.request.headers.host;
    return host ? host : null;
  }

  headers() {
    if (this._preparedHeaders) return this._preparedHeaders;

    const req = this.request;

    this._preparedHeaders = {};

    for (const key in req.headers) {
      this._preparedHeaders[key] = req.headers[key];
    }

    return this._preparedHeaders;
  }

  consume() {
    return this.input;
  }
}

class ResponseOutparam {
  constructor(request, response) {
    this.request = request;
    this.response = response;
    this._resolve = null;
    this.promise = new Promise(resolve => {
      this._resolve = resolve;
    });
  }

  set(result) {
    this.result = result;
    this._resolve();
  }

  async finish() {
    const result = this.result;
    const res = this.response;

    if (result.call("tag").toJS() === "ok") {
      const response = result.call("value");
      const headers = response.call("headers").toJS();

      Object.entries(headers).forEach(([key, value]) => {
        res.set(key, value);
      });

      if (headers["set-cookie"]) {
        const cookies = setCookieParser.parse(headers["set-cookie"]);
        cookies.forEach(cookie => {
          res.cookie(cookie.name, cookie.value, {
            domain: cookie.domain,
            path: cookie.path,
            expires: cookie.expires,
            sameSite: cookie.sameSite.toLowerCase()
          });
        });
      }

      if (headers["location"]) {
        const location = headers["location"];
        if (location.startsWith("http://localhost:3000/")) {
          res.set("location", location.replace("http://localhost:3000", ""));
        }
      }

      let body = response.call("body").toJS();

      if (headers["content-type"]?.startsWith("image/")) {
        try {
          const buffer = Buffer.from(body, 'base64');

          if (buffer.length === 0) {
            console.error('Empty buffer after base64 conversion');
            res.status(500).send('Failed to decode image data');
            return;
          }

          res.status(response.call("status_code").toJS());
          res.type(headers["content-type"]);
          res.send(buffer);
          return;
        } catch(e) {
          console.error(`failed to decode image (${headers["content-type"]}):`, e)
          res.status(500).send(`Express Error: ${e.message}`);
        }
      }

      res.status(response.call("status_code").toJS());
      res.send(body);
    } else {
      res.status(result.call("error").toJS()).send(`Internal Application Error: ${result.call("value").toJS()}`);
    }
  }
}

// We convert files from forms into data URIs and handle them via Rack DataUriUploads middleware.
const DATA_URI_UPLOAD_PREFIX = "BbC14y";

const fileToDataURI = async (file, mimetype) => {
  const base64 = file.toString('base64');
  const mimeType = mimetype || 'application/octet-stream';
  return `data:${mimeType};base64,${base64}`;
};

const flattenObject = (obj, prefix = '') => {
  const params = {};

  for (const [key, value] of Object.entries(obj)) {
    const paramKey = prefix ? `${prefix}[${key}]` : key;

    if (value === null || value === undefined) {
      // ignore
    } else if (typeof value === 'object' && !Array.isArray(value)) {
      const nestedParams = flattenObject(value, paramKey);
      Object.entries(nestedParams).forEach(([k, v]) => params[k] = v);
    } else if (Array.isArray(value)) {
      value.forEach((item, index) => {
        if (typeof item === 'object' && item !== null) {
          const nestedParams = flattenObject(item, `${paramKey}[${index}]`);
          Object.entries(nestedParams).forEach(([k, v]) => params[k] = v);
        } else {
          params[`${paramKey}[]`] = item.toString();
        }
      });
    } else {
      params[paramKey] = value.toString();
    }
  }

  return params;
};

const prepareInput = async (req) => {
  let input = null;

  if (
    req.method === "POST" ||
    req.method === "PUT" ||
    req.method === "PATCH"
  ) {
    const contentType = req.get("content-type");

    if (contentType?.includes("multipart/form-data")) {
      const formData = flattenObject({ ...req.body });

      if (req.files && req.files.length > 0) {
        await Promise.all(
          req.files.map(async (file) => {
            try {
              const dataURI = await fileToDataURI(file.buffer, file.mimetype);
              formData[file.fieldname] = DATA_URI_UPLOAD_PREFIX + dataURI;
            } catch (e) {
              console.warn(
                `Failed to convert file into data URI: ${e.message}. Ignoring file form input ${file.fieldname}`,
              );
            }
          })
        );
      }

      const params = new URLSearchParams(formData);
      input = params.toString();
    } else {
      let body = '';
      req.on('data', chunk => {
        body += chunk.toString();
      });
      await new Promise(resolve => req.on('end', resolve));
      input = body;
    }
  }

  return input;
}

export class RequestQueue {
  constructor(handler){
    this._handler = handler;
    this.isProcessing = false;
    this.queue = [];
  }

  async respond(req, res) {
    if (this.isProcessing) {
      return new Promise((resolve) => {
        this.queue.push({ req, res, resolve });
      });
    }
    await this.process(req, res);
    queueMicrotask(() => this.tick());
  }

  async process(req, res) {
    this.isProcessing = true;
    try {
      await this._handler(req, res);
    } catch (e) {
      console.error(e);
      res.status(500).send(`Application Error: ${e.message}`);
    } finally {
      this.isProcessing = false;
    }
  }

  async tick() {
    if (this.queue.length === 0) {
      return;
    }
    const { req, res, resolve } = this.queue.shift();
    await this.process(req, res);
    resolve();
    queueMicrotask(() => this.tick());
  }
}

let counter = 0;

const requestHandler = async (vm, req, res) => {
  const input = await prepareInput(req);
  const incomingRequest = new IncomingRequest(req, input);
  const responseOut = new ResponseOutparam(req, res);

  const requestId = `req-${counter++}`
  const responseId = `res-${counter}`

  global[requestId] = incomingRequest;
  global[responseId] = responseOut;

  const command = `
    $incoming_handler.handle(
      Rack::WASI::IncomingRequest.new("${requestId}"),
      Rack::WASI::ResponseOutparam.new("${responseId}")
    )
  `

  try {
    await vm.evalAsync(command);
    await responseOut.promise;
    await responseOut.finish();
  } catch (e) {
    res.status(500).send(`Unexpected Error: ${e.message.slice(0, 100)}`);
  } finally {
    delete global[requestId];
    delete global[responseId];
  }
}

export const createRackServer = async (vm, opts = {}) => {
  const { skipRackup } = opts;

  if (!skipRackup) {
    // Set up Rack handler (if hasn't been already set up)
    await vm.evalAsync(`
      require "rack/builder"
      require "rack/wasi/incoming_handler"

      app = Rack::Builder.load_file("./config.ru")

      $incoming_handler = Rack::WASI::IncomingHandler.new(app)
    `)
  }

  const app = express();

  const upload = multer({ storage: multer.memoryStorage() });
  app.use(upload.any());
  app.use(createFrameLocationTrackingMiddleware());

  const queue = new RequestQueue((req, res) => requestHandler(vm, req, res));

  app.all('*path', async (req, res) => {
    await queue.respond(req, res)
  });

  return app;
}
