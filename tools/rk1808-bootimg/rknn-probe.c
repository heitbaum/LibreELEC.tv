// SPDX-License-Identifier: MIT
/*
 * End to end test of the npu path: host -> librknn_api -> npu_transfer_proxy
 * -> usb -> rknn_server on the die -> galcore -> the hardware.
 *
 * rknn_demo is the vendor's test and is not usable here: it wants minigui,
 * librga, librkuvc, libv4l2 and a camera. librknn_api.so needs only libstdc++,
 * libm, libgcc_s and libc, all of which LibreELEC has, so this talks to the
 * api directly instead.
 *
 *     aarch64-linux-gnu-gcc -o rknn-probe rknn-probe.c -I<hdr> -L<lib> -lrknn_api
 *     LD_LIBRARY_PATH=<lib> ./rknn-probe mobilenet_ssd.rknn
 *
 * The input is synthetic - zeros, passed through without conversion. The point
 * is to exercise the transport and the hardware, not to classify anything, so
 * the output values are not checked for meaning. What matters is that
 * rknn_init reaches the die, the sdk query round trips the *driver* version
 * from the die, and rknn_run returns without error.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rknn_api.h"

static void *slurp(const char *path, uint32_t *len)
{
    FILE *f = fopen(path, "rb");
    void *buf;
    long n;

    if (!f) {
        perror(path);
        return NULL;
    }
    fseek(f, 0, SEEK_END);
    n = ftell(f);
    fseek(f, 0, SEEK_SET);

    buf = malloc(n);
    if (!buf || fread(buf, 1, n, f) != (size_t)n) {
        fprintf(stderr, "%s: short read\n", path);
        fclose(f);
        free(buf);
        return NULL;
    }
    fclose(f);
    *len = (uint32_t)n;
    return buf;
}

int main(int argc, char **argv)
{
    rknn_context ctx = 0;
    rknn_sdk_version ver;
    rknn_input_output_num io;
    rknn_tensor_attr in_attr;
    rknn_input in;
    rknn_output *outs;
    uint32_t model_len = 0;
    void *model;
    int ret, i;

    if (argc != 2) {
        fprintf(stderr, "usage: %s <model.rknn>\n", argv[0]);
        return 2;
    }

    model = slurp(argv[1], &model_len);
    if (!model)
        return 1;
    printf("model      %s, %u bytes\n", argv[1], model_len);

    ret = rknn_init(&ctx, model, model_len, 0);
    if (ret < 0) {
        fprintf(stderr, "rknn_init failed: %d\n", ret);
        return 1;
    }
    printf("rknn_init  ok\n");

    /* this one crosses the usb link and comes back from the die */
    memset(&ver, 0, sizeof(ver));
    ret = rknn_query(ctx, RKNN_QUERY_SDK_VERSION, &ver, sizeof(ver));
    if (ret < 0)
        fprintf(stderr, "sdk version query failed: %d\n", ret);
    else
        printf("api        %s\ndriver     %s\n", ver.api_version, ver.drv_version);

    memset(&io, 0, sizeof(io));
    ret = rknn_query(ctx, RKNN_QUERY_IN_OUT_NUM, &io, sizeof(io));
    if (ret < 0) {
        fprintf(stderr, "in/out query failed: %d\n", ret);
        goto out;
    }
    printf("tensors    %u in, %u out\n", io.n_input, io.n_output);

    memset(&in_attr, 0, sizeof(in_attr));
    in_attr.index = 0;
    ret = rknn_query(ctx, RKNN_QUERY_INPUT_ATTR, &in_attr, sizeof(in_attr));
    if (ret < 0) {
        fprintf(stderr, "input attr query failed: %d\n", ret);
        goto out;
    }
    printf("input[0]   %s, %u dims [", in_attr.name, in_attr.n_dims);
    for (i = 0; i < (int)in_attr.n_dims; i++)
        printf("%s%u", i ? " " : "", in_attr.dims[i]);
    printf("], %u bytes\n", in_attr.size);

    memset(&in, 0, sizeof(in));
    in.index = 0;
    in.size = in_attr.size;
    in.buf = calloc(1, in_attr.size);
    in.pass_through = 1;      /* raw, no conversion - we only want a run */
    if (!in.buf) {
        ret = -1;
        goto out;
    }

    ret = rknn_inputs_set(ctx, 1, &in);
    if (ret < 0) {
        fprintf(stderr, "inputs_set failed: %d\n", ret);
        goto out;
    }
    printf("inputs_set ok\n");

    ret = rknn_run(ctx, NULL);
    if (ret < 0) {
        fprintf(stderr, "rknn_run failed: %d\n", ret);
        goto out;
    }
    printf("rknn_run   ok\n");

    outs = calloc(io.n_output, sizeof(*outs));
    for (i = 0; i < (int)io.n_output; i++)
        outs[i].want_float = 1;

    ret = rknn_outputs_get(ctx, io.n_output, outs, NULL);
    if (ret < 0) {
        fprintf(stderr, "outputs_get failed: %d\n", ret);
        goto out;
    }
    for (i = 0; i < (int)io.n_output; i++) {
        float *f = outs[i].buf;
        printf("output[%d]  %u bytes, first values %.4f %.4f %.4f %.4f\n",
               i, outs[i].size,
               f ? f[0] : 0.0f, f ? f[1] : 0.0f,
               f ? f[2] : 0.0f, f ? f[3] : 0.0f);
    }
    rknn_outputs_release(ctx, io.n_output, outs);

    printf("\nPASS - the model ran on the npu\n");
    ret = 0;

out:
    rknn_destroy(ctx);
    return ret < 0 ? 1 : 0;
}
