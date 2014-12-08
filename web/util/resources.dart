part of vf_deformation;

void _handleFetchError(ErrorEvent err) {
  log(err.toString(), LOG_ERROR);
  HttpRequest tar = err.target;
  // We have headers, the error code at the very least will be useful
  if (tar.readyState >= 2) {
    log(tar.status.toString(), LOG_ERROR);
  }
  // There is some response text, perhaps we can get useful information from it?
  if (tar.readyState >= 3) {
    log(tar.responseText.toString(), LOG_ERROR);
  }
  // We want to propegate the error up the call stack, there isn't a good way
  // to recover
  throw err;
}

Map<String, HttpRequest> _collapseResourceList(list) {
  Map<String, HttpRequest> output = new Map<String, HttpRequest>();
  for (var item in list) {
    var resp = item[0];
    var path = item[1];
    output[path] = resp;
  }
  return output;
}

/// Returns a map from a url to the result of requesting that url
Future<Map<String, HttpRequest>> fetchResources(List<String> urls) {
  List<Future<HttpRequest>> actions = [];
  for (var i in urls) {
    Future req = new
      Future(() => log("Fetching $i"))
      .then ((_) => HttpRequest.request(i))
      .catchError(_handleFetchError)
      .then ((HttpRequest resp) {
        log("Fetched $i");
        return [resp, i];
      });
    actions.add(req);
  }
  return Future.wait(actions)
    .then(_collapseResourceList);
}
