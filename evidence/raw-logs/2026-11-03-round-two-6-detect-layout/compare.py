import sys
def load(f):
    d={}
    for l in open(f):
        n,sc,r=l.rstrip('\n').split('\t'); a,b=map(int,sc.split('/')); d[n]=(a,b,r)
    return d
base, new = sys.argv[1], sys.argv[2]
for m in ('strict','full'):
    A=load(f'eval-{base}-{m}.txt'); B=load(f'eval-{new}-{m}.txt')
    print('== model', m, base, '->', new)
    b=w=0; okA=okB=0
    for k in sorted(A):
        fa=A[k][0]/A[k][1]; fb=B[k][0]/B[k][1]; okA+=fa==1; okB+=fb==1
        if abs(fa-fb)>1e-9 or k.startswith('be') or k.startswith('fr'):
            tag='BETTER' if fb>fa else ('WORSE' if fb<fa else 'same')
            b+=tag=='BETTER'; w+=tag=='WORSE'
            print(f"  {k:12} {A[k][0]}/{A[k][1]} {A[k][2]}  ->  {B[k][0]}/{B[k][1]} {B[k][2]}  {tag}")
    print(f'  totals: better {b}, worse {w}, of {len(A)}; always right: {okA} -> {okB}')
