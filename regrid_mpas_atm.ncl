
;======================================================================
; ESMF_regrid_10.ncl
;
; Concepts illustrated:
;   - Interpolating from one grid to another using ESMF_regrid
;   - Interpolating data from an MPAS grid to 0.25 degree grid
;======================================================================
; This example is identical to ESMF_all_10.ncl, except it does the
; regridding in one call to "ESMF_regrid".  See ESMF_wgts_10.ncl
; for a faster example of regridding using an existing weights file.
;======================================================================
; This example uses the ESMF application "ESMF_RegridWeightGen" to 
; generate the weights.
;
; For more information about ESMF:
;
;        http://www.earthsystemmodeling.org/
;
; This script uses built-in functions that will be in NCL version
; 6.1.0.
;======================================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
; --- read in grid file name
gridFilename  = "/glade/derecho/scratch/patc/S2S_REPO/mpasa60.L32/grids/x1.163842.grid.nc"
gridfile = addfile(gridFilename,"r")
lonCell = tofloat(gridfile->lonCell)
latCell = tofloat(gridfile->latCell)
printVarSummary(latCell)

;  ---Convert to degrees from radians
RAD2DEG = get_r2d("float")      ; Radian to Degree
print(RAD2DEG)
lonCell = lonCell*RAD2DEG
latCell = latCell*RAD2DEG

;---Retrieve data
ensdir = "/glade/derecho/scratch/huili7/ENSEMBLES/S2Scfsv2_old/archive/"
VARS = (/"Z500"/)
nvars = dimsizes(VARS)
print(nvars)

do imem=0,0
  casename = "f.e23b17.FLTHIST_mpasa60.S2S.L58_S2Scfsv2.0"+imem
  casedir = ensdir+casename+"/atm/hist/"  
  srcFileName = casename+".cam.h2a.2021-02-09-00000.nc"
  print(casedir+srcFileName)

  do iv = 0, nvars-1
    sfile = addfile(casedir+srcFileName,"r")
    arr = sfile->$VARS(iv)$
    lat    = sfile->lat
    lon    = sfile->lon
    printVarSummary(arr)

   ; -- regridding  
    Opt                 = True                     ; Regridding optioins

    Opt@SrcFileName     = "../MPAS_ESMF.nc"           ; output files
    Opt@SrcESMF  = True
    Opt@DstFileName     = "World_0.25deg_SCRIP_nomask.nc"
    Opt@WgtFileName     = "MPAS_2_World_nomask.nc"
    Opt@ForceOverwrite  = True

    Opt@SrcGridLat      = latCell                  ; source gri
    Opt@SrcGridLon      = lonCell
    Opt@InputFileName   = srcFileName              ; optional

    Opt@DstGridType     = "0.25deg"                ; destination grid
    Opt@DstTitle        = "World Grid 0.25 degree resolution no mask"
    Opt@DstLLCorner     = (/-89.75d,   0.00d /)
    Opt@DstURCorner     = (/ 89.75d, 359.75d /) 

    

    Opt@SkipWgtGen      = False
    Opt@Debug           = False


  ;var_regrid = ESMF_regrid(TS,Opt)
    var_regrid = ESMF_regrid_with_weights(arr,"MPAS_2_World_nomask.nc",False)
    fout = addfile(casedir+"regrid_"+VARS(iv)+"_"+srcFileName,"c")
    fout->$VARS(iv)$ = var_regrid

    end do
  end do
end