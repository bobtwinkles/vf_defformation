part of vf_deformation;

Node _log_node = query('#log');

const int LOG_ERROR   = 0;
const int LOG_WARNING = 1;
const int LOG_INFO    = 2;
const int LOG_DEBUG   = 3;

void log(String s, [level = 4]) {
  SpanElement ins = new SpanElement();

  String desired_class = "log-item";
  if (level == LOG_ERROR) {
    desired_class += " log-item-error";
  }
  ins.setAttribute("class", desired_class);
  ins.appendHtml(s);

  _log_node.append(ins);
}
