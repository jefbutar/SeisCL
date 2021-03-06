/*------------------------------------------------------------------------
 * Copyright (C) 2016 For the list of authors, see file AUTHORS.
 *
 * This file is part of SeisCL.
 *
 * SeisCL is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.0 of the License only.
 *
 * SeisCL is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SeisCL. See file COPYING and/or
 * <http://www.gnu.org/licenses/gpl-3.0.html>.
 --------------------------------------------------------------------------*/

/*Update of the stresses in 2D SH*/

/*Define useful macros to be able to write a matrix formulation in 2D with OpenCl */
#define lbnd (FDOH+NAB)

#define rho(z,x)    rho[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define rip(z,x)    rip[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define rjp(z,x)    rjp[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define rkp(z,x)    rkp[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define muipkp(z,x) muipkp[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define mujpkp(z,x) mujpkp[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define muipjp(z,x) muipjp[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define mu(z,x)        mu[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define pi(z,x)      pi[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define gradrho(z,x)  gradrho[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define gradM(z,x)  gradM[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define gradmu(z,x)  gradmu[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define gradtaup(z,x)  gradtaup[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define gradtaus(z,x)  gradtaus[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]

#define taus(z,x)        taus[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define tausipkp(z,x) tausipkp[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define tausipjp(z,x) tausipjp[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define tausjpkp(z,x) tausjpkp[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]
#define taup(z,x)        taup[((x)-FDOH)*(NZ-2*FDOH)+((z)-FDOH)]

#define vx(z,x)  vx[(x)*(NZ)+(z)]
#define vy(z,x)  vy[(x)*(NZ)+(z)]
#define vz(z,x)  vz[(x)*(NZ)+(z)]
#define sxx(z,x) sxx[(x)*(NZ)+(z)]
#define szz(z,x) szz[(x)*(NZ)+(z)]
#define sxz(z,x) sxz[(x)*(NZ)+(z)]
#define sxy(z,x) sxy[(x)*(NZ)+(z)]
#define syz(z,x) syz[(x)*(NZ)+(z)]

#define rxx(z,x,l) rxx[(l)*NX*NZ+(x)*NZ+(z)]
#define rzz(z,x,l) rzz[(l)*NX*NZ+(x)*NZ+(z)]
#define rxz(z,x,l) rxz[(l)*NX*NZ+(x)*NZ+(z)]
#define rxy(z,x,l) rxy[(l)*NX*NZ+(x)*NZ+(z)]
#define ryz(z,x,l) ryz[(l)*NX*NZ+(x)*NZ+(z)]

#define psi_sxx_x(z,x) psi_sxx_x[(x)*(NZ-2*FDOH)+(z)]
#define psi_sxz_x(z,x) psi_sxz_x[(x)*(NZ-2*FDOH)+(z)]
#define psi_sxz_z(z,x) psi_sxz_z[(x)*(2*NAB)+(z)]
#define psi_szz_z(z,x) psi_szz_z[(x)*(2*NAB)+(z)]
#define psi_sxy_x(z,x) psi_sxy_x[(x)*(NZ-2*FDOH)+(z)]
#define psi_syz_z(z,x) psi_syz_z[(x)*(2*NAB)+(z)]

#define psi_vyx(z,x) psi_vyx[(x)*(NZ-2*FDOH)+(z)]
#define psi_vyz(z,x) psi_vyz[(x)*(2*NAB)+(z)]


#if LOCAL_OFF==0

#define lvar(z,x)  lvar[(x)*lsizez+(z)]

#endif


#define vxout(y,x) vxout[(y)*NT+(x)]
#define vyout(y,x) vyout[(y)*NT+(x)]
#define vzout(y,x) vzout[(y)*NT+(x)]
#define vx0(y,x) vx0[(y)*NT+(x)]
#define vy0(y,x) vy0[(y)*NT+(x)]
#define vz0(y,x) vz0[(y)*NT+(x)]
#define rx(y,x) rx[(y)*NT+(x)]
#define ry(y,x) ry[(y)*NT+(x)]
#define rz(y,x) rz[(y)*NT+(x)]

#define PI (3.141592653589793238462643383279502884197169)


#ifdef __OPENCL_VERSION__
#define FUNDEF __kernel
#define LFUNDEF
#define GLOBARG __global
#define LOCARG __local float *lvar
#define LOCDEF
#define BARRIER barrier(CLK_LOCAL_MEM_FENCE);
#else
#define FUNDEF extern "C" __global__
#define LFUNDEF extern "C" __device__
#define GLOBARG
#define LOCARG float *nullarg
#define LOCDEF extern __shared__ float lvar[];
#define BARRIER __syncthreads();
#endif


FUNDEF void update_s(int offcomm, int nt,
                       GLOBARG float *vy,
                       GLOBARG float *sxy,        GLOBARG float *syz,
                       GLOBARG float *mu,
                       GLOBARG float *rxy,        GLOBARG float *ryz,
                       GLOBARG float *taus,
                       GLOBARG float *eta,
                       GLOBARG float *taper,
                       GLOBARG float *K_x,        GLOBARG float *a_x,          GLOBARG float *b_x,
                       GLOBARG float *K_x_half,   GLOBARG float *a_x_half,     GLOBARG float *b_x_half,
                       GLOBARG float *K_z,        GLOBARG float *a_z,          GLOBARG float *b_z,
                       GLOBARG float *K_z_half,   GLOBARG float *a_z_half,     GLOBARG float *b_z_half,
                       GLOBARG float *psi_vyx,    GLOBARG float *psi_vyz,
                       LOCARG)

{

    LOCDEF
    int i,k,l,ind;
    float f;
    float sumrxy,sumryz;
    float b,c,d;
    float lmu, ltaus;
#if LVE>0
    float leta[LVE];
#endif
    float vyx,vyz;
    float vxyyx,vyzzy,vxzzx,vxxyyzz,vyyzz,vxxzz,vxxyy;
    
    float lsxy, lsyz;
    
// If we use local memory
#if LOCAL_OFF==0
#ifdef __OPENCL_VERSION__
    int lsizez = get_local_size(0)+2*FDOH;
    int lsizex = get_local_size(1)+2*FDOH;
    int lidz = get_local_id(0)+FDOH;
    int lidx = get_local_id(1)+FDOH;
    int gidz = get_global_id(0)+FDOH;
    int gidx = get_global_id(1)+FDOH+offcomm;
#else
    int lsizez = blockDim.x+2*FDOH;
    int lsizex = blockDim.y+2*FDOH;
    int lidz = threadIdx.x+FDOH;
    int lidx = threadIdx.y+FDOH;
    int gidz = blockIdx.x*blockDim.x + threadIdx.x+FDOH;
    int gidx = blockIdx.y*blockDim.y + threadIdx.y+FDOH+offcomm;
#endif
    
#define lvy lvar
    
// If local memory is turned off
#elif LOCAL_OFF==1
    
#ifdef __OPENCL_VERSION__
    int gid = get_global_id(0);
    int glsizez = (NZ-2*FDOH);
    int gidz = gid%glsizez+FDOH;
    int gidx = (gid/glsizez)+FDOH+offcomm;
#else
    int lsizez = blockDim.x+2*FDOH;
    int lsizex = blockDim.y+2*FDOH;
    int lidz = threadIdx.x+FDOH;
    int lidx = threadIdx.y+FDOH;
    int gidz = blockIdx.x*blockDim.x + threadIdx.x+FDOH;
    int gidx = blockIdx.y*blockDim.y + threadIdx.y+FDOH+offcomm;
#endif
    
    
#define lvy vy
#define lidx gidx
#define lidz gidz
    
#endif

// Calculation of the velocity spatial derivatives
    {
#if LOCAL_OFF==0
        lvy(lidz,lidx)=vy(gidz,  gidx);
        if (lidx<2*FDOH)
            lvy(lidz,lidx-FDOH)=vy(gidz,gidx-FDOH);
        if (lidx+lsizex-3*FDOH<FDOH)
            lvy(lidz,lidx+lsizex-3*FDOH)=vy(gidz,gidx+lsizex-3*FDOH);
        if (lidx>(lsizex-2*FDOH-1))
            lvy(lidz,lidx+FDOH)=vy(gidz,gidx+FDOH);
        if (lidx-lsizex+3*FDOH>(lsizex-FDOH-1))
            lvy(lidz,lidx-lsizex+3*FDOH)=vy(gidz,gidx-lsizex+3*FDOH);
        if (lidz<2*FDOH)
            lvy(lidz-FDOH,lidx)=vy(gidz-FDOH,gidx);
        if (lidz>(lsizez-2*FDOH-1))
            lvy(lidz+FDOH,lidx)=vy(gidz+FDOH,gidx);
        BARRIER
#endif
        
#if   FDOH==1
        vyx = (lvy(lidz,lidx+1)-lvy(lidz,lidx));
        vyz = (lvy(lidz+1,lidx)-lvy(lidz,lidx));
#elif FDOH==2
        vyx = (HC1*(lvy(lidz,lidx+1)-lvy(lidz,lidx))+
               HC2*(lvy(lidz,lidx+2)-lvy(lidz,lidx-1)));
        
        vyz = (HC1*(lvy(lidz+1,lidx)-lvy(lidz,lidx))+
               HC2*(lvy(lidz+2,lidx)-lvy(lidz-1,lidx)));
#elif FDOH==3
        vyx = (HC1*(lvy(lidz,lidx+1)-lvy(lidz,lidx))+
               HC2*(lvy(lidz,lidx+2)-lvy(lidz,lidx-1))+
               HC3*(lvy(lidz,lidx+3)-lvy(lidz,lidx-2)));
        
        vyz = (HC1*(lvy(lidz+1,lidx)-lvy(lidz,lidx))+
               HC2*(lvy(lidz+2,lidx)-lvy(lidz-1,lidx))+
               HC3*(lvy(lidz+3,lidx)-lvy(lidz-2,lidx)));
#elif FDOH==4
        vyx = (HC1*(lvy(lidz,lidx+1)-lvy(lidz,lidx))+
               HC2*(lvy(lidz,lidx+2)-lvy(lidz,lidx-1))+
               HC3*(lvy(lidz,lidx+3)-lvy(lidz,lidx-2))+
               HC4*(lvy(lidz,lidx+4)-lvy(lidz,lidx-3)));
        
        vyz = (HC1*(lvy(lidz+1,lidx)-lvy(lidz,lidx))+
               HC2*(lvy(lidz+2,lidx)-lvy(lidz-1,lidx))+
               HC3*(lvy(lidz+3,lidx)-lvy(lidz-2,lidx))+
               HC4*(lvy(lidz+4,lidx)-lvy(lidz-3,lidx)));
#elif FDOH==5
        vyx = (HC1*(lvy(lidz,lidx+1)-lvy(lidz,lidx))+
               HC2*(lvy(lidz,lidx+2)-lvy(lidz,lidx-1))+
               HC3*(lvy(lidz,lidx+3)-lvy(lidz,lidx-2))+
               HC4*(lvy(lidz,lidx+4)-lvy(lidz,lidx-3))+
               HC5*(lvy(lidz,lidx+5)-lvy(lidz,lidx-4)));
        
        vyz = (HC1*(lvy(lidz+1,lidx)-lvy(lidz,lidx))+
               HC2*(lvy(lidz+2,lidx)-lvy(lidz-1,lidx))+
               HC3*(lvy(lidz+3,lidx)-lvy(lidz-2,lidx))+
               HC4*(lvy(lidz+4,lidx)-lvy(lidz-3,lidx))+
               HC5*(lvy(lidz+5,lidx)-lvy(lidz-4,lidx)));
#elif FDOH==6
        vyx = (HC1*(lvy(lidz,lidx+1)-lvy(lidz,lidx))+
               HC2*(lvy(lidz,lidx+2)-lvy(lidz,lidx-1))+
               HC3*(lvy(lidz,lidx+3)-lvy(lidz,lidx-2))+
               HC4*(lvy(lidz,lidx+4)-lvy(lidz,lidx-3))+
               HC5*(lvy(lidz,lidx+5)-lvy(lidz,lidx-4))+
               HC6*(lvy(lidz,lidx+6)-lvy(lidz,lidx-5)));
        
        vyz = (HC1*(lvy(lidz+1,lidx)-lvy(lidz,lidx))+
               HC2*(lvy(lidz+2,lidx)-lvy(lidz-1,lidx))+
               HC3*(lvy(lidz+3,lidx)-lvy(lidz-2,lidx))+
               HC4*(lvy(lidz+4,lidx)-lvy(lidz-3,lidx))+
               HC5*(lvy(lidz+5,lidx)-lvy(lidz-4,lidx))+
               HC6*(lvy(lidz+6,lidx)-lvy(lidz-5,lidx)));
#endif
    }
    
    
// To stop updating if we are outside the model (global id must be a multiple of local id in OpenCL, hence we stop if we have a global id outside the grid)
#if LOCAL_OFF==0
#if COMM12==0
    if (gidz>(NZ-FDOH-1) || (gidx-offcomm)>(NX-FDOH-1-LCOMM) ){
        return;
    }
#else
    if (gidz>(NZ-FDOH-1) ){
        return;
    }
#endif
#endif

 
// Correct spatial derivatives to implement CPML
#if ABS_TYPE==1
    {
        
        if (gidz>NZ-NAB-FDOH-1){
            
            i =gidx-FDOH;
            k =gidz - NZ+NAB+FDOH+NAB;
            ind=2*NAB-1-k;
            
            psi_vyz(k,i) = b_z_half[ind] * psi_vyz(k,i) + a_z_half[ind] * vyz;
            vyz = vyz / K_z_half[ind] + psi_vyz(k,i);
        }
        
#if FREESURF==0
        else if (gidz-FDOH<NAB){
            
            i =gidx-FDOH;
            k =gidz-FDOH;
            
            psi_vyz(k,i) = b_z_half[k] * psi_vyz(k,i) + a_z_half[k] * vyz;
            vyz = vyz / K_z_half[k] + psi_vyz(k,i);
            
        }
#endif
        
#if DEVID==0 & MYLOCALID==0
        if (gidx-FDOH<NAB){
            
            i =gidx-FDOH;
            k =gidz-FDOH;
            
            psi_vyx(k,i) = b_x_half[i] * psi_vyx(k,i) + a_x_half[i] * vyx;
            vyx = vyx / K_x_half[i] + psi_vyx(k,i);
            
        }
#endif
        
#if DEVID==NUM_DEVICES-1 & MYLOCALID==NLOCALP-1
        if (gidx>NX-NAB-FDOH-1){
            
            i =gidx - NX+NAB+FDOH+NAB;
            k =gidz-FDOH;
            ind=2*NAB-1-i;
            
            psi_vyx(k,i) = b_x_half[ind] * psi_vyx(k,i) + a_x_half[ind] * vyx;
            vyx = vyx  /K_x_half[ind] + psi_vyx(k,i);
        }
#endif
    }
#endif

// Read model parameters into local memory
    {
#if LVE==0
        
        f=mu(gidz,gidx);
        
#else
        
        lmu=mu(gidz,gidx);
        ltaus=taus(gidz,gidx);
        
        for (l=0;l<LVE;l++){
            leta[l]=eta[l];
        }
        
        f=lm*(1.0+ (float)LVE*ltausipjp);
        d=lmu*ltaus;
        
#endif
    }

// Update the stresses
    {
#if LVE==0
        
        sxy(gidz,gidx)+=(f*vyx);
        syz(gidz,gidx)+=(f*vyz);
        
        
#else
        
        /* computing sums of the old memory variables */
        sumrxy=sumryz=0;
        for (l=0;l<LVE;l++){
            sumrxy+=rxy(gidz,gidx,l);
            sumryz+=ryz(gidz,gidx,l);
        }
        
        /* updating components of the stress tensor, partially */
        
        lsxy=(f*vyx)+(DT2*sumrxy);
        lsyz=(f*vyz)+(DT2*sumryz);
        
        sumrxy=sumryz=0;
        for (l=0;l<LVE;l++){
            b=1.0/(1.0+(leta[l]*0.5));
            c=1.0-(leta[l]*0.5);
            
            rxy(gidz,gidx,l)=b*(rxy(gidz,gidx,l)*c-leta[l]*(d*vyx));
            ryz(gidz,gidx,l)=b*(ryz(gidz,gidx,l)*c-leta[l]*(d*vyz));
            
            sumrxy+=rxy(gidz,gidx,l);
            sumryz+=ryz(gidz,gidx,l);
        }
        
        /* and now the components of the stress tensor are
         completely updated */
        sxy(gidz,gidx)+=lsxy+(DT2*sumrxy);
        syz(gidz,gidx)+=lsyz+(DT2*sumryz);
        
        
#endif
    }

// Absorbing boundary
#if abstype==2
    {
#if FREESURF==0
        if (gidz-FDOH<NAB){
            sxy(gidz,gidx)*=taper[gidz-FDOH];
            syz(gidz,gidx)*=taper[gidz-FDOH];
        }
#endif
        
        if (gidz>NZ-NAB-FDOH-1){
            sxy(gidz,gidx)*=taper[NZ-FDOH-gidz-1];
            syz(gidz,gidx)*=taper[NZ-FDOH-gidz-1];
        }
        
#if DEVID==0 & MYLOCALID==0
        if (gidx-FDOH<NAB){
            sxy(gidz,gidx)*=taper[gidx-FDOH];
            syz(gidz,gidx)*=taper[gidx-FDOH];
        }
#endif
        
#if DEVID==NUM_DEVICES-1 & MYLOCALID==NLOCALP-1
        if (gidx>NX-NAB-FDOH-1){
            sxy(gidz,gidx)*=taper[NX-FDOH-gidx-1];
            syz(gidz,gidx)*=taper[NX-FDOH-gidx-1];
        }
#endif
    }
#endif
    
}

