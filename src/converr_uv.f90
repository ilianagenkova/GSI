module converr_uv
!$$$   module documentation block
!                .      .    .                                       .
! module:    converr_uv
!   prgmmr: su          org: np2                date: 2007-03-15
! abstract:  This module contains variables and routines related
!            to the assimilation of conventional observations error
!
! program history log:
!   2007-03-15  su  - original code - move reading observation error table 
!                                     from read_prepbufr to here so all the 
!                                     processor can have the new error information 
!
! Subroutines Included:
!   sub converr_uv_read      - allocate arrays for and read in conventional error table 
!   sub converr_uv_destroy   - destroy conventional error arrays
!
! Variable Definitions:
!   def etabl_uv             -  the array to hold the error table
!   def ptabl_uv             -  the array to have vertical pressure values
!
! attributes:
!   language: f90
!   machine:  ibm RS/6000 SP
!
!$$$ end documentation block

use kinds, only:r_kind,i_kind,r_single
use constants, only: zero
use obsmod, only : oberrflg 
implicit none

! set default as private
  private
! set subroutines as public
  public :: converr_uv_read
  public :: converr_uv_destroy
! set passed variables as public
  public :: etabl_uv,ptabl_uv

  integer(i_kind),save:: ietabl_uv,itypex,itypey,lcount,iflag,k,m
  real(r_single),save,allocatable,dimension(:,:,:) :: etabl_uv
  real(r_kind),save,allocatable,dimension(:)  :: ptabl_uv

contains


  subroutine converr_uv_read(mype)
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    convinfo_err      read conventional information file
!
!     prgmmr:    su    org: np2                date: 2007-03-15
!
! abstract:  This routine reads the conventional error table file
!
! program history log:
!   2008-06-04  safford -- add subprogram doc block
!   2013-05-14  guo     -- add status and iostat in open, to correctly
!                          handle the error case of "obs error table not
!                          available to 3dvar".
!
!   input argument list:
!
!   output argument list:
!
! attributes:
!   language:  f90
!   machine:   ibm RS/6000 SP
!
!$$$ end documentation block
     use constants, only: half
     implicit none

     integer(i_kind),intent(in   ) :: mype

     integer(i_kind):: ier

     allocate(etabl_uv(100,33,6))

     etabl_uv=1.e9_r_kind
      
     ietabl_uv=19
     open(ietabl_uv,file='errtable_uv',form='formatted',status='old',iostat=ier)
     if(ier/=0) then
        write(6,*)'CONVERR:  ***WARNING*** obs error table ("errtable") not available to 3dvar.'
        lcount=0
        oberrflg=.false.
        return
     endif

     rewind ietabl_uv
     etabl_uv=1.e9_r_kind
     lcount=0
     loopd : do 
        read(ietabl_uv,100,IOSTAT=iflag,end=120) itypey
        if( iflag /= 0 ) exit loopd
100     format(1x,i3)
        lcount=lcount+1
        itypex=itypey-199
        do k=1,33
           read(ietabl_uv,110)(etabl_uv(itypex,k,m),m=1,6)
110        format(1x,6e12.5)
        end do
     end do   loopd
120  continue

     if(lcount<=0 .and. mype==0) then
        write(6,*)'CONVERR:  ***WARNING*** obs error table not available to 3dvar.'
        oberrflg=.false.
     else
        if(mype == 0) write(6,*)'CONVERR:  using observation errors from user provided table'
        allocate(ptabl_uv(34))
        ptabl_uv=zero
        ptabl_uv(1)=etabl_uv(20,1,1)
        do k=2,33
           ptabl_uv(k)=half*(etabl_uv(20,k-1,1)+etabl_uv(20,k,1))
        enddo
        ptabl_uv(34)=etabl_uv(20,33,1)
     endif

     close(ietabl_uv)

     return
  end subroutine converr_uv_read


subroutine converr_uv_destroy
!$$$  subprogram documentation block
!                .      .    .                                       .
! subprogram:    converr_uv_destroy      destroy conventional information file
!     prgmmr:    su    org: np2                date: 2007-03-15
!
! abstract:  This routine destroys arrays from converr_uv file
!
! program history log:
!   2007-03-15  su 
!
!   input argument list:
!
!   output argument list:
!
! attributes:
!   language: f90
!   machine:  ibm rs/6000 sp
!
!$$$
     implicit none

     deallocate(etabl_uv,ptabl_uv)
     return
  end subroutine converr_uv_destroy

end module converr_uv



