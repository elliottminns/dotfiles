; extends

; Topcoat and Leptos both use view! for HTML-like templates. This more
; specific injection takes precedence over Rust's generic macro injection.
(macro_invocation
  macro: [
    (scoped_identifier
      name: (identifier) @_macro_name)
    (identifier) @_macro_name
  ]
  (token_tree) @injection.content
  (#eq? @_macro_name "view")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "html")
  (#set! injection.include-children))

; Topcoat embeds Rust expressions in parentheses inside the template. Parse each
; top-level parenthesized group as Rust again so expressions such as `$(value)`,
; `href=(href!(page))`, and component arguments keep normal Rust highlighting.
(macro_invocation
  macro: [
    (scoped_identifier
      name: (identifier) @_macro_name)
    (identifier) @_macro_name
  ]
  (token_tree
    (token_tree) @injection.content)
  (#eq? @_macro_name "view")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "rust"))
