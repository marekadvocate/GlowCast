/* Inert diagnostic: run the upstream arg parser + packet generator for the
 * QuadCast 2 S and dump exactly what would be sent. No hardware touched. */
#include <stdio.h>
#include "modules/argparser.h"
#include "modules/rgbmodes.h"

#define QUADCAST_2S_PID 0x02b5

static void dump_cs(const char *name, const struct colscheme *c)
{
    int i;
    printf("  %s: mode=%s br=%d spd=%d dly=%d colors=", name,
           c->mode ? c->mode : "(null)", c->br, c->spd, c->dly);
    for (i = 0; i < COLORS_CNT; i++)
        printf("%d ", c->colors[i]);
    printf("\n        colors(hex)=");
    for (i = 0; i < COLORS_CNT; i++)
        printf("0x%06x ", c->colors[i] & 0xffffff);
    printf("\n");
}

int main(int argc, const char **argv)
{
    struct colschemes cs;
    datpack *data_arr;
    int pck_cnt = 0, verbose = 0, i, j;

    parse_arg(&cs, argc, argv, &verbose);
    printf("=== after parse_arg (pid before override = 0x%04x) ===\n", cs.pid);
    dump_cs("upper", &cs.upper);
    dump_cs("lower", &cs.lower);

    cs.pid = QUADCAST_2S_PID;
    data_arr = parse_colorscheme(&cs, &pck_cnt);

    printf("\n=== after parse_colorscheme: pck_cnt=%d ===\n", pck_cnt);
    for (j = 0; j < pck_cnt; j++) {
        printf("packet %d:\n  ", j);
        for (i = 0; i < DATA_PACKET_SIZE; i++) {
            printf("%02x ", data_arr[j][i]);
            if ((i + 1) % 16 == 0) printf("\n  ");
        }
        printf("\n");
    }
    return 0;
}
