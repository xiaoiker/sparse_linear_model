#ifndef __UTILS_H__
#define __UTILS_H__

#include "useblas.h"
#include "useinterfaces.h"

/* TODO: Make this independent from useinterfaces, move non-blas-related stuff
 * from useblas.h here.
 * TODO: Move print_matrix to mkl_ext (mkl_utils).
 */

void print_matrix(DOUBLE *matrix, INT M, INT N);
void print_matrix_int(INT *matrix, INT M, INT N);
void rand_normal_custom(DOUBLE *r1, DOUBLE *r2, DOUBLE std);
void quicksort(DOUBLE* data, INT *indices, INT N);
void randperm(INT *perm, INT N);
void randchoose (INT *chosen, INT populationSize, INT sampleSize);

/*
 * TODO: Add conditional malloc? I.e., only alloc if the passed buffer is NULL.
 */

#endif /* __UTILS_H__ */
