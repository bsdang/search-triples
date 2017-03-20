/*function stripEmbeddedTriplesFromJson(context, params, content) {
    var result = content.toObject();
    var image = {"image": result.image}
    return image;
};*/

function stripEmbeddedTriplesFromJson(context, params, content) {
  if (context.inputType.search('json') >= 0) {
    var result = content.toObject();
    if (context.acceptTypes) {                 /* read */
      delete result.triples
    }
    return result;
  } else {
    /* Pass thru for non-JSON documents */
    return content;
  }
};

var start = xdmp.elapsedTime();
exports.transform = stripEmbeddedTriplesFromJson;
xdmp.log("Metrics::Transform::stripEmbeddedTriplesFromJson took: " + xdmp.elapsedTime().subtract(start).toString(), "info");