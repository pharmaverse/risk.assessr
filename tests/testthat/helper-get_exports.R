make_r6_generator_with_non_func <- function() {
  gen <- list(
    public_methods = list(
      real_method   = function(x) x,
      non_func_slot = "I am a string, not a function"
    )
  )
  class(gen) <- "R6ClassGenerator"
  gen
}

make_fake_ggproto <- function() {
  structure(list(), class = c("ggproto", "gg", "environment"))
}

make_fake_s7_generic_with_methods <- function() {
  structure(function(...) {}, class = c("S7_generic", "function"))
}

make_fake_s7_generic_no_methods <- function() {
  structure(function(x) x * 7L, class = c("S7_generic", "function"))
}

make_fake_s7_class <- function() {
  structure(list(), class = c("S7_class", "environment"))
}

make_fake_rlang_pronoun <- function() {
  structure(list(), class = "rlang_fake_data_pronoun")
}
