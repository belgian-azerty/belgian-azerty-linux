#include <stdio.h>
#include <string.h>
#include <xkbcommon/xkbcommon.h>
/* For a Belgian keymap with/without caps:be_windows, print the text of keys a(AD01), 2(AE02), u-grave(AC11)
   for every combination of Shift (depressed) x Lock (none/depressed/latched/locked) x group 0/1. */
static void run(const char *opts){
  struct xkb_context *c=xkb_context_new(0);
  struct xkb_rule_names n={"evdev","pc105","be,us","",opts};
  struct xkb_keymap *k=xkb_keymap_new_from_names(c,&n,0);
  if(!k){printf("compile failed %s\n",opts);return;}
  xkb_mod_index_t S=xkb_keymap_mod_get_index(k,XKB_MOD_NAME_SHIFT),L=xkb_keymap_mod_get_index(k,XKB_MOD_NAME_CAPS);
  int keys[3]={24+8-8+ 16+8-16+8 ,0,0}; /* placeholder */
  xkb_keycode_t kc[3]={24+8,11+8,40+8}; /* evdev+8: KEY_Q(16)->AD01 is 24? */
  kc[0]=16+8; kc[1]=3+8; kc[2]=40+8; /* KEY_Q=16 (AD01 = Belgian a), KEY_2=3 (AE02), KEY_APOSTROPHE=40 (AC11 = u-grave) */
  const char *ln[4]={"none","dep","lat","lock"};
  printf("== options: %s\n",opts);
  for(int g=0;g<2;g++)for(int l=0;l<4;l++)for(int s=0;s<2;s++){
    struct xkb_state *st=xkb_state_new(k);
    xkb_mod_mask_t dep=(s?1u<<S:0)|(l==1?1u<<L:0),lat=(l==2?1u<<L:0),lock=(l==3?1u<<L:0);
    xkb_state_update_mask(st,dep,lat,lock,0,0,g);
    char out[64]="";
    for(int i=0;i<3;i++){char b[16];xkb_state_key_get_utf8(st,kc[i],b,sizeof b);strcat(out,b[0]?b:"-");strcat(out," ");}
    printf("group%d Lock=%-4s Shift=%d : %s\n",g,ln[l],s,out);
    xkb_state_unref(st);
  }
  xkb_keymap_unref(k);xkb_context_unref(c);
}
int main(){run("lv3:ralt_switch");run("lv3:ralt_switch,caps:be_windows");return 0;}
