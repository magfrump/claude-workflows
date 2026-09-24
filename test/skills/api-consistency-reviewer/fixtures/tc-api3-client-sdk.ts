// Public entry point of the @acme/workspace-client package.

import { HttpClient } from "./http";

export interface ListOptions {
  limit?: number;
  cursor?: string;
}

export interface Page<T> {
  data: T[];
  nextCursor: string | null;
}

export interface User {
  id: string;
  email: string;
  displayName: string;
}

export interface Project {
  id: string;
  name: string;
  ownerId: string;
}

export interface Team {
  id: string;
  name: string;
  memberIds: string[];
}

export class WorkspaceClient {
  constructor(private readonly http: HttpClient) {}

  getUser(userId: string): Promise<User> {
    return this.http.get(`/users/${encodeURIComponent(userId)}`);
  }

  listUsers(options: ListOptions = {}): Promise<Page<User>> {
    return this.http.get("/users", { query: options });
  }

  createUser(input: Omit<User, "id">): Promise<User> {
    return this.http.post("/users", input);
  }

  deleteUser(userId: string): Promise<void> {
    return this.http.delete(`/users/${encodeURIComponent(userId)}`);
  }

  getProject(projectId: string): Promise<Project> {
    return this.http.get(`/projects/${encodeURIComponent(projectId)}`);
  }

  listProjects(options: ListOptions = {}): Promise<Page<Project>> {
    return this.http.get("/projects", { query: options });
  }

  createProject(input: Omit<Project, "id">): Promise<Project> {
    return this.http.post("/projects", input);
  }

  deleteProject(projectId: string): Promise<void> {
    return this.http.delete(`/projects/${encodeURIComponent(projectId)}`);
  }

  // BEGIN CHANGE UNDER REVIEW
  fetchTeam(teamId: string): Promise<Team> {
    return this.http.get(`/teams/${encodeURIComponent(teamId)}`);
  }

  listTeams(options: ListOptions = {}): Promise<Page<Team>> {
    return this.http.get("/teams", { query: options });
  }

  createTeam(input: Omit<Team, "id">): Promise<Team> {
    return this.http.post("/teams", input);
  }

  deleteTeam(teamId: string): Promise<void> {
    return this.http.delete(`/teams/${encodeURIComponent(teamId)}`);
  }
  // END CHANGE UNDER REVIEW
}
