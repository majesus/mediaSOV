# Figuras estáticas del apartado 13 del README (método Peckham 1,5 ampliado).
# Uso: python3 data-raw/figuras_peckham.py man/figures   (requiere matplotlib)
# Marca E de sov_plantilla(): SOM 8 %, SOV 9 %; objetivo 10 % en dos años; k = ln(3)/2.
import math, sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
plt.rcParams.update({"font.family":"Liberation Sans","font.size":10.5,"axes.linewidth":0.8})
out=sys.argv[1]
kP=math.log(3)/2; A,B=6.4,-0.38; m=1+B
NAVY="#1F3A5F"; RED="#C8102E"; ORA="#C07A12"; GREY="#8A8A8A"
def plan(s0,s1,T,k,a,b):
    mm=1+b; r=math.exp(-k*mm*T); si=(s1-r*s0)/(1-r); return a+mm*si
def path(s0,v,k,t,a,b):
    mm=1+b; si=(v-a)/mm; return si+(s0-si)*math.exp(-k*mm*t)
s0,v0,s1=8.0,9.0,10.0
plans=[("Referencia de paridad (SOV = SOM)",0.0,0.0,NAVY),("Referencia de Jones (α = 6,4; β = −0,38)",A,B,RED)]
ts=[i/50*2 for i in range(51)]

# ---------- Mapa ESOV-SOM
fig,ax=plt.subplots(figsize=(7.2,4.8),dpi=130)
xs=[0,20]
ax.axhline(0,color=GREY,lw=0.9,ls=(0,(2,2)))
ax.plot(xs,[A+B*x for x in xs],color=ORA,lw=1.6,ls=(0,(6,3)),label="Recta de Jones: ESOV = 6,4 − 0,38·SOM")
for lab,a,b,c in plans:
    v=plan(s0,s1,2,kP,a,b)
    S=[path(s0,v,kP,t,a,b) for t in ts]
    ax.plot([s0,s0],[v0-s0,v-s0],color=c,lw=1.2,ls=(0,(1,2)))
    ax.annotate("",xy=(s0,v-s0),xytext=(s0,v0-s0+0.15),arrowprops=dict(arrowstyle="-|>",color=c,lw=1.2))
    ax.plot(S,[v-s for s in S],color=c,lw=2.2,label=f"{lab}: SOV = {v:.1f} %".replace(".",","))
    for t in (0,1,2):
        s=path(s0,v,kP,t,a,b); ax.plot(s,v-s,"o",color=c,ms=6,zorder=5)
        ax.text(s+0.12,v-s+0.22,f"año {t}",color=c,fontsize=8.5,ha="left")
    eq=a+m*s1 if a else s1
    ax.annotate("",xy=(s1,eq-s1),xytext=(s1,v-s1-0.15),arrowprops=dict(arrowstyle="-|>",color=c,lw=1.2,ls=(0,(1,2))))
    ax.plot(s1,eq-s1,"s",mfc="white",mec=c,ms=6.5,mew=1.5,zorder=6)
ax.text(s1+0.25,0.25,"año 3: mantenimiento",color=NAVY,fontsize=8.5)
ax.text(s1+0.25,A+B*s1+0.25,"año 3: mantenimiento",color=RED,fontsize=8.5)
ax.plot(s0,v0-s0,"o",color="black",ms=7,zorder=6); ax.text(s0-0.15,v0-s0-0.05,"Marca E hoy\n(SOM 8, SOV 9)",fontsize=8.5,ha="right",va="top")
ax.set_xlim(5,15); ax.set_ylim(-1.5,7.5)
ax.set_xlabel("SOM: cuota de mercado (%)"); ax.set_ylabel("ESOV = SOV − SOM (puntos porcentuales)")
ax.set_title("Mapa ESOV–SOM: el plan de dos años",fontweight="bold",fontsize=12)
ax.legend(loc="upper right",fontsize=8.3,frameon=False)
for sp in ax.spines.values(): sp.set_visible(True)
fig.tight_layout(); fig.savefig(f"{out}/README-peckham-esov-1.png",facecolor="white"); plt.close(fig)

# ---------- Mapa SOV-SOM (SOV en abscisas, SOM en ordenadas)
fig,ax=plt.subplots(figsize=(7.2,4.8),dpi=130)
L=[0,18]
ax.fill_between(L,L,[18,18],color="#F2F2F2",zorder=0)
ax.plot(L,L,color="black",lw=1.3)
ax.plot([A+m*y for y in (0,18)],[0,18],color=ORA,lw=1.6,ls=(0,(6,3)),label="Recta de Jones: SOV = 6,4 + 0,62·SOM")
for lab,a,b,c in plans:
    v=plan(s0,s1,2,kP,a,b); eq=a+m*s1 if a else s1
    ax.annotate("",xy=(v,s0),xytext=(v0+0.1,s0),arrowprops=dict(arrowstyle="-|>",color=c,lw=1.2,ls=(0,(1,2))))
    ax.plot([v,v],[s0,s1],color=c,lw=2.2,label=f"{lab.split(' (')[0]}: SOV = {v:.1f} %".replace(".",","))
    for t in (1,2):
        s=path(s0,v,kP,t,a,b); ax.plot(v,s,"o",color=c,ms=6,zorder=5); ax.text(v+0.15,s-0.12,f"año {t}",color=c,fontsize=8.5,va="top")
    ax.annotate("",xy=(eq,s1),xytext=(v-0.1,s1),arrowprops=dict(arrowstyle="-|>",color=c,lw=1.2,ls=(0,(1,2))))
    ax.plot(eq,s1,"s",mfc="white",mec=c,ms=6.5,mew=1.5,zorder=6)
ax.plot(v0,s0,"o",color="black",ms=7,zorder=6); ax.text(v0+0.1,s0-0.2,"Marca E hoy\n(SOV 9, SOM 8)",fontsize=8.5,ha="left",va="top")
ax.text(5.3,12.8,"ZONA COSECHA\n(vende más de lo que habla)",fontsize=8,fontweight="bold",color="#555555",va="top")
ax.text(16.8,5.3,"ZONA INVERSIÓN\n(habla más de lo que vende)",fontsize=8,fontweight="bold",color=RED,ha="right")
ax.text(10.0,10.35,"□ SOV de mantenimiento (año 3)",fontsize=7.8,color="#444444",ha="center")
ax.set_xlim(5,17); ax.set_ylim(5,13)
ax.set_xlabel("Cuota de voz, SOV (%)"); ax.set_ylabel("Cuota de mercado, SOM (%)")
ax.set_title("Mapa SOV–SOM: el plan de dos años",fontweight="bold",fontsize=12)
ax.legend(loc="lower right",bbox_to_anchor=(1.0,0.13),fontsize=8,frameon=False)
fig.tight_layout(); fig.savefig(f"{out}/README-peckham-mapa-1.png",facecolor="white"); plt.close(fig)
