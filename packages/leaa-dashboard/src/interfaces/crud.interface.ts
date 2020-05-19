import { CreateQueryParams } from '@nestjsx/crud-request';

export interface ICrudListQueryParams extends CreateQueryParams {
  q?: string;
  s?: string;
  categoryId?: string;
  banderId?: string;
  tagId?: string;
  userId?: string;
}