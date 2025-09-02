import sketch/css

pub fn title() {
  css.class([css.color("red"), css.font_family("sans-serif")])
}

pub fn task() {
  css.class([])
}

pub fn task_done() {
  css.class([css.text_decoration("line-through")])
}
