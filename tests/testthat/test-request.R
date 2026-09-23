# Shared HTTP policy: private-address guard, body decoding.

test_that("is_private_ip flags loopback, private, link-local, and reserved ranges", {
  priv <- c("127.0.0.1", "10.1.2.3", "172.16.0.1", "172.31.255.255", "192.168.1.1",
            "169.254.169.254", "100.64.0.1", "0.0.0.0", "::1", "fe80::1", "fd00::1",
            "::ffff:127.0.0.1", "224.0.0.1")
  pub <- c("8.8.8.8", "172.32.0.1", "192.169.0.1", "2001:4860:4860::8888", "100.128.0.1")
  expect_true(all(is_private_ip(priv)))
  expect_false(any(is_private_ip(pub)))
})

test_that("url_block_reason refuses non-http schemes and private literals", {
  expect_match(url_block_reason("file:///etc/passwd"), "only http and https")
  expect_match(url_block_reason("ftp://example.org/x"), "only http and https")
  expect_match(url_block_reason("http://169.254.169.254/latest/meta-data/"), "non-public")
  expect_match(url_block_reason("http://127.0.0.1:8080/"), "non-public")
  expect_true(is.na(url_block_reason("https://8.8.8.8/")))
})

test_that("the private-host guard stops assess_fair before any request is sent", {
  withr::local_options(rfair.block_private_hosts = TRUE)
  seen <- local_http(list())
  a <- assess_fair("http://169.254.169.254/latest/meta-data/", use_datacite = FALSE)
  expect_false(a$resolution$ok)
  expect_match(a$resolution$error, "non-public address")
  expect_length(seen$urls, 0L)
})

test_that("body_text decodes declared charsets and skips binary bodies", {
  latin <- httr2::response(200L, headers = list(`Content-Type` = "text/html; charset=ISO-8859-1"),
                           body = as.raw(c(0x63, 0x61, 0x66, 0xe9)))
  expect_identical(body_text(latin), "café")
  pdf <- httr2::response(200L, headers = list(`Content-Type` = "application/pdf"),
                         body = charToRaw("%PDF-1.7"))
  expect_null(body_text(pdf))
  nul <- httr2::response(200L, headers = list(`Content-Type` = "text/plain"),
                         body = as.raw(c(0x61, 0x00, 0x62)))
  expect_identical(body_text(nul), "ab")
})

test_that("a landing page served as a binary file still counts as resolved", {
  local_http(list(route("https://example.org/paper.pdf", "%PDF-1.7", type = "application/pdf")))
  a <- assess_fair("https://example.org/paper.pdf", use_datacite = FALSE)
  expect_true(a$resolution$ok)
  expect_identical(a$resolved_url, "https://example.org/paper.pdf")
})

test_that("the guard pins the connection to the address it checked", {
  withr::local_options(rfair.block_private_hosts = TRUE)
  local_mocked_bindings(resolve_host = function(host) "93.184.215.14")
  pinned <- NULL
  httr2::local_mocked_responses(function(req) {
    pinned <<- req$options$resolve
    httr2::response(200L, url = req$url)
  })
  resp <- rfair_perform(rfair_request("https://example.org/x"))
  expect_true(is_response(resp))
  expect_identical(pinned, "example.org:443:93.184.215.14")

  local_mocked_bindings(resolve_host = function(host) c("93.184.215.14", "127.0.0.1"))
  expect_match(url_block_reason("https://rebind.example/"), "non-public address \\(127.0.0.1\\)")
})

test_that("guarded redirects drop credentials when they leave the host", {
  withr::local_options(rfair.block_private_hosts = TRUE)
  local_mocked_bindings(resolve_host = function(host) "93.184.215.14")
  sent <- list()
  httr2::local_mocked_responses(function(req) {
    sent[[req$url]] <<- names(httr2::req_get_headers(req, "reveal"))
    if (grepl("^https://a\\.example", req$url)) {
      loc <- if (grepl("/first$", req$url)) "/second" else "https://b.example/final"
      return(httr2::response(302L, url = req$url, headers = list(Location = loc)))
    }
    httr2::response(200L, url = req$url)
  })
  req <- httr2::req_auth_bearer_token(rfair_request("https://a.example/first"), "secret")
  resp <- rfair_perform(req)
  expect_true(is_response(resp))
  expect_true("Authorization" %in% sent[["https://a.example/second"]])   # same host keeps it
  expect_false("Authorization" %in% sent[["https://b.example/final"]])   # other host does not
})

test_that("body_text survives charsets iconv does not know", {
  resp <- httr2::response(200L, headers = list(`Content-Type` = "text/html; charset=utf8mb4"),
                          body = charToRaw("café"))
  expect_identical(body_text(resp), "café")
})
