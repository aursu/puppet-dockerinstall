// MANAGED BY PUPPET - dockerinstall::daemon_proxy
//
// Access handler for the Docker daemon stream proxy.
//
// The policy itself is NOT here. The allow-list lives in two nginx maps that
// Puppet renders, so it stays reviewable in configuration and diffable in git:
//
//   $ssl_client_s_dn_cn  extracts the CN from the client certificate subject
//   $docker_ok           1 when that CN is allow-listed, 0 otherwise
//
// This shim exists only because the stream module has no way to refuse a
// connection based on a variable - ngx_stream_access_module filters by address
// only, and there is no `return` in stream context. njs supplies the verb.
//
// Keeping the list out of JavaScript means this file never changes when the
// allow-list does.
//
// Two distinct rejections, in two different places, so look in the right one:
//
//   unknown CA, expired, or no certificate  -> refused by the TLS handshake,
//                                              because the server block sets
//                                              ssl_verify_client on. This
//                                              handler never runs.
//   valid certificate, CN not allow-listed  -> refused here, and logged below.
//
// The '(none presented)' fallback is therefore unreachable as configured: by
// the time this runs, the certificate has already passed cryptographic
// verification. It is kept because it stops being unreachable the moment
// ssl_verify_client is relaxed to `optional`, and a log line reading
// "refused client certificate undefined" would be a poor way to discover that.

function access(s) {
    if (s.variables.docker_ok === '1') {
        s.allow();
        return;
    }

    s.error('dockerd proxy: refused client certificate '
            + (s.variables.ssl_client_s_dn || '(none presented)'));
    s.deny();
}

export default { access };
