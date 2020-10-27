import { NewsStatsComponent } from './news-stats/news-stats.component';
import { NewsSearchComponent } from './news-search/news-search.component';
import { UnderConstructionComponent } from './under-construction/under-construction.component';
import { NewsDashComponent } from './news-dash/news-dash.component';

import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

const routes: Routes = [
  //{path: 'search',component:NewsSearchComponent},
  //{path: 'mydash',component: NewsDashComponent},
  {path: 'news/stats',component: NewsStatsComponent},
  //{path: '/underConstruction',component: UnderConstructionComponent},
  //{path: '**',component:NewsSearchComponent },

];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }


